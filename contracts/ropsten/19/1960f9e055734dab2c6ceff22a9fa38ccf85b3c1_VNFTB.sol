/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

// SPDX-License-Identifier: GPL-3.0
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




contract VNFTB {
    uint[100]  nft_ids;
    uint public total_donatees;
    uint public max_donatees_per_nft;
    uint public votes;
    // struct donatee {
    //     address ad;
    //     uint amount;
    // }
    //mapping(uint => donatee[]) public nfts_donatees;
    //mapping(uint => address[]) public nfts_donatees;

    address[] public donatees;
    mapping(address => uint) public donatee_amount;
    mapping(address => uint) public donatee_exits; // 0 no exits; 1 exists; 2 deleted;
    mapping(address => uint) public donatee_nft_adder;
    mapping(uint    => uint) public nft_donatee_count;
    mapping(uint    => uint) public nft_donate_amount;
    mapping(uint    => uint) public nft_vote;
 
    constructor() public {
        nft_ids[0] = 1;
        nft_ids[1] = 2;
        max_donatees_per_nft = 10;
    }
    
    // function get_nft_ids() view public returns (uint[100] memory){
    //     return nft_ids;
    // }
    
    function has_this_nft(uint _nft_id) view public returns (bool){
        address _contract = 0x73A97635b511d06CC676b0b08060277947F2EB38;
        if (IERC721(_contract).ownerOf(_nft_id) == msg.sender){
            return true;
        }else{
            return false;}
    }

    function nft_free_space(uint _nft_id) view public returns (bool){
        if (nft_donatee_count[_nft_id] < max_donatees_per_nft){
            return true;
        }else{
            return false;}
    }

    function add_donatee(address _donatee, uint _nft_id)  public returns (uint) {
        // 0 success
        // 1 false(no nft holder)
        // 2 false(nft no space)
        // 3 false(donatee already exists)
        // 4 success(donatee already deleted, just resign for exists)

        //if (!has_this_nft(_nft_id))    { return 1;}
        if (!nft_free_space(_nft_id)) { return 2;}
        if (donatee_exits[_donatee] == 1) { return 3;}
        if (donatee_exits[_donatee] == 2) { 
            donatee_exits[_donatee] = 1;
            donatee_nft_adder[_donatee] = _nft_id;
            donatee_amount[_donatee] = 0;
            nft_donatee_count[_nft_id] += 1;
            total_donatees += 1;
            return 4;
        }
        if (donatee_exits[_donatee] == 0) {
            donatees.push(_donatee);
            donatee_exits[_donatee] = 1;
            donatee_nft_adder[_donatee] = _nft_id;
            donatee_amount[_donatee] = 0;
            nft_donatee_count[_nft_id] += 1;
            total_donatees += 1;
            return 0;     
        }
    }

    function remove_donatee(address _donatee, uint _nft_id)  public returns (uint) {
        // 0 success
        // 1 false(no nft holder)
        // 2 false(nft not adder of donatee)
        // 3 false(donatee deleted already)
        // 4 false(donatee not exists)

        //if (!has_this_nft(_nft_id))   { return 1;}
        if (donatee_nft_adder[_donatee] != _nft_id) { return 2;}
        if (donatee_exits[_donatee] == 2) { return 3;}
        if (donatee_exits[_donatee] == 0) { return 4;}
        
        // if (donatee_exits[_donatee] == 1)
        // clean unclaimed ether of the donatee
        uint claim_amount = donatee_amount[_donatee];
        if (claim_amount > 0) {payable(_donatee).transfer(claim_amount);}
        donatee_amount[_donatee] = 0;

        // decrease records
        donatee_exits[_donatee] = 2;
        nft_donatee_count[_nft_id] -= 1;
        total_donatees -= 1;
        return 0;
    }
    // event Received(address, uint);
    //     receive() external payable {
    //         emit Received(msg.sender, msg.value);
    //     }

    function donate(uint _nft_id) external payable returns (uint per_amount){ 
        nft_donate_amount[_nft_id] += msg.value;
        uint per_amount = msg.value/total_donatees;

        for (uint i=0; i<donatees.length; i++){
            address ad = donatees[uint(i)];
            if (donatee_exits[ad] == 1) {
                donatee_amount[ad] += per_amount;
            }
        }
        return per_amount;
    }
 
    function claim() external returns (uint claim_amount){
        uint claim_amount = donatee_amount[msg.sender];
        if (claim_amount > 0){
            payable(msg.sender).transfer(claim_amount);
            donatee_amount[msg.sender] = 0;
            return claim_amount;
        }
        return 0;
    }

    function vote(uint _nft_id)  public returns (uint) {
        // 0 success
        // 1 false(no nft holder)
        // 2 false(voted already)

        //if (!has_this_nft(_nft_id))    { return 1;}
        if (nft_vote[_nft_id] == 1) { return 2;}
        nft_vote[_nft_id] = 1;
        votes += 1;
        if (votes > 50){
            max_donatees_per_nft += 100;
            for (uint i=0; i<nft_ids.length; i++){
                nft_vote[nft_ids[uint(i)]] = 0;
            }
        }
        return 0;
    }

    function unvote(uint _nft_id)  public returns (uint) {
        // 0 success
        // 1 false(no nft holder)
        // 2 false(not vote yet)

        //if (!has_this_nft(_nft_id))    { return 1;}
        if (nft_vote[_nft_id] == 0) { return 2;}
        nft_vote[_nft_id] = 0;
        votes -= 1;
        return 0;
    }



}