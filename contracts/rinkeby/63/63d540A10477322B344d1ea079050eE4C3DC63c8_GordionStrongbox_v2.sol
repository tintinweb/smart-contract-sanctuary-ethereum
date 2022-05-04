/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: VRF Test/GordionStrongboxAvaDice_v2.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;




interface IAvaGame {

    function houseEdgeCalculator(address player)

        external

        view

        returns (uint houseEdge);

}



interface IERC721_2 is IERC721 {

    function exists(uint tokenId) external returns (bool);



    function tokenOfOwnerByIndex(address owner, uint256 index)

        external

        view

        returns (uint256 tokenId);



    function totalSupply() external view returns (uint256);

}



contract GordionStrongbox_v2 {

    /**

    Events

     */

    event DepositAVAX(address indexed sender, uint256 amount);

    event DepositToken(address indexed sender, uint256 amount);



    modifier onlyOwners() {

        require(isOwner[msg.sender], "0x03");

        _;

    }



    mapping(address => bool) public isOwner;

    mapping(address => bool) public isGame;



    address private nftAddress;

    IERC721_2 public nft;

    uint public claimableTotal;



    uint256 public nftHolderReward = 7000;



    address public immutable dev =

        address(0xe650580Ab0B22C253e13257430b1102dB8C27d1E);

    address public immutable vl =

        address(0x991c2252B11d28100F0F2fa3cdFB821056D5414d);

    address public immutable cube =

        address(0x1152Ff6d620aa0ED8EC3C83711E8f2f756E5B8D5);

    address public immutable avadice =

        address(0x4f63428BD8AAb63bEEd04ef0CC6F49286123d2bF);



    uint256 public reflectionBalance;

    uint256 public totalDividend;

    mapping(uint256 => uint256) public lastDividendAt;

    uint8 public claimFlag = 1;



    mapping(uint => bool) isRegistered;

    uint public rewardPool;



    constructor(address _nftAddress) {

        isOwner[msg.sender] = true;

        setNFTAdress(_nftAddress);

    }



    function setNFTAdress(address _nftAddress) public onlyOwners {

        require(_nftAddress != address(0x0));

        nftAddress = _nftAddress;

        nft = IERC721_2(nftAddress);

    }



    function addGame(address[] calldata _games) external onlyOwners {

        for (uint i = 0; i < _games.length; i++) {

            isGame[_games[i]] = true;

        }

    }



    function removeGame(address[] calldata _games) external onlyOwners {

        for (uint i = 0; i < _games.length; i++) {

            isGame[_games[i]] = false;

        }

    }



    function setNFTHolderReward(uint _nftHolderReward) external onlyOwners {

        nftHolderReward = _nftHolderReward;

    }



    function addOwner(address[] calldata _owners) external onlyOwners {

        for (uint i = 0; i < _owners.length; i++) {

            isOwner[_owners[i]] = true;

        }

    }



    function removeOwner(address[] calldata _owners) external onlyOwners {

        for (uint i = 0; i < _owners.length; i++) {

            isOwner[_owners[i]] = false;

        }

    }



    /*--------------PAYMENT MANAGEMENT--------------*/

    function depositAVAX() external payable {

        if (isGame[msg.sender]) {

            IAvaGame game = IAvaGame(msg.sender);

            uint houseEdge = game.houseEdgeCalculator(tx.origin);

            claimableTotal +=

                (((msg.value * 1000) / (houseEdge + 1000)) * houseEdge) /

                1000;

        }

        emit DepositAVAX(msg.sender, msg.value);

    }



    function addClaimable() external payable {

        claimableTotal += msg.value;

    }



    function executePaymentAVAX(uint256 amount, address _to) external {

        require(isGame[msg.sender] || isOwner[msg.sender]);

        require(

            (address(this).balance - amount) >= (claimableTotal + rewardPool)

        );

        require(_to != address(0x0));

        payable(_to).transfer(amount);

    }



    function withdrawAVAX(uint256 amount, address _to) external {

        require(isOwner[msg.sender]);

        require(_to != address(0x0));

        payable(_to).transfer(amount);

    }



    function splitDividend() external onlyOwners {

        require(address(this).balance > claimableTotal);



        uint claimableNFTReward = (claimableTotal * nftHolderReward) / 10000;

        reflectDividend(claimableNFTReward);

        uint teamShare = (claimableTotal - claimableNFTReward) / 4;

        payable(dev).transfer(teamShare);

        payable(vl).transfer(teamShare);

        payable(cube).transfer(teamShare);

        payable(avadice).transfer(teamShare);

        claimableTotal = 0;

    }



    /*-----------------REVARD MANAGEMENT------------------*/

    function setClaimFlag(uint8 flag) external onlyOwners {

        claimFlag = flag;

    }



    function claimRewards() external {

        require(claimFlag == 1, "claim is disabled");

        uint count = nft.balanceOf(msg.sender);

        require(count > 0);

        uint256 balance = 0;

        for (uint i = 0; i < count; i++) {

            uint tokenId = nft.tokenOfOwnerByIndex(msg.sender, i);

            require(

                isRegistered[tokenId],

                "Token is not registered. Please contact support."

            );

            uint256 _reflectionBalance = getReflectionBalance(tokenId);

            balance = balance + _reflectionBalance;

            lastDividendAt[tokenId] = totalDividend;

        }

        rewardPool -= balance;

        payable(msg.sender).transfer(balance);

    }



    function getReflectionBalances() external view returns (uint256 _total) {

        uint count = nft.balanceOf(msg.sender);

        _total = 0;



        for (uint i = 0; i < count; i++) {

            uint tokenId = nft.tokenOfOwnerByIndex(msg.sender, i);

            uint256 _reflectionBalance = getReflectionBalance(tokenId);

            _total = _total + _reflectionBalance;

        }

    }



    function getReflectionBalance(uint256 tokenId)

        public

        view

        returns (uint256 _reflectionBalance)

    {

        _reflectionBalance = totalDividend - lastDividendAt[tokenId];

    }



    function reflectDividend(uint256 amount) private {

        reflectionBalance = reflectionBalance + amount;

        rewardPool += amount;

        totalDividend = totalDividend + (amount / (nft.totalSupply() - 2222));

    }



    function reflectToOwners() external payable {

        reflectDividend(msg.value);

    }



    function registerNFT(uint[] calldata tokenIds) external onlyOwners {

        for (uint i = 0; i < tokenIds.length; i++) {

            if (!isRegistered[tokenIds[i]]) {

                lastDividendAt[tokenIds[i]] = totalDividend;

                isRegistered[tokenIds[i]] = true;

            }

        }

    }

}