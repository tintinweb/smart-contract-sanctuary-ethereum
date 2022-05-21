/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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

   function safeMint(address to, uint256 tokenId, string memory uri)external;
        
}


interface IERC20{
    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function totalSupply() external view returns (uint );

    function decimals() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function approve(address sender , uint value)external returns(bool);

    function allowance(address sender, address spender) external view returns (uint256);

    function transfer(address recepient , uint value) external returns(bool);

    function transferFrom(address sender,address recepient, uint value) external returns(bool);

    event Transfer(address indexed from , address indexed to , uint value);

    event Approval(address indexed sender , address indexed  spender , uint value);
}


library incrermentUsingAssemblyLanguageOpcodes{
    function increment(uint numberToIncrement) internal pure returns(uint c){
        assembly{
            c := add(numberToIncrement,1)
        }

        
        return c;
    }

    function add(uint a, uint b) internal pure returns(uint c){
        assembly{
            c := add(a,b)
        }
        return c;
    }
}

contract NFT_MintingPlatform {
    using incrermentUsingAssemblyLanguageOpcodes for uint;

    address public Mint_Owner;
    // address public USDToken;
    IERC721 public ERC721;
    IERC20 public USDT;

    uint public totalUsersMintedTokenId;

    mapping(address => bool) public whiteListedUsers;
    mapping(address => mintedUserDetails) public MintedNFTsUserDetails;

    /* Type of Asset for Minting*/
    enum AssetType{
        /* AssetType 0 for ETHER*/
        ETHER,
        /* AssetType 1 for USDT*/
        USDT
    }

    struct Order{
        address toAddr;
        string uri;
        AssetType assetType;
    }

    /* User details. */
    struct mintedUserDetails{
        /* Minter userAddr*/
        address userAddr;
        /* total NFTs minted by this user*/
        uint mintedNFTs;
        /* token ids minted*/
        uint[] tokenIDs;
    }

     /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    modifier OnlyOwner(){
        require(Mint_Owner == msg.sender,"Only Admin!!!");
        _;
    }

    constructor(address OwnerAddr, address _ERC721,address _USDToken) {
        require(OwnerAddr != address(0),"Owner can't be zero address!!!");
        Mint_Owner = OwnerAddr;
        ERC721 = IERC721(_ERC721);
        USDT = IERC20(_USDToken);
    }

    function mintNFT(Order memory _Order, Sig memory sig,uint USDTokenAmount)public payable{
        require(msg.sender != address(0),"Call from zero address!!!");
        require(!whiteListedUsers[msg.sender],"Only WhiteListed user's can mint!!!");
        require(_Order.toAddr != address(0),"Minting can't be done for zero address!!!");

        if(_Order.assetType == AssetType.ETHER){
            require(msg.value == USDTokenAmount,"Deposit ether for Minting NFT!!!");
            require(validateOrderHash(_Order,sig),"Incorrect signature while depositing ETHER!!!");
            (bool success,) = Mint_Owner.call{value : msg.value}("");
                if(success){
                    totalUsersMintedTokenId += incrermentUsingAssemblyLanguageOpcodes.increment(totalUsersMintedTokenId);
                    mintedUserDetails storage MintedUserdetails = MintedNFTsUserDetails[_Order.toAddr];
                    MintedUserdetails.userAddr = _Order.toAddr;
                    MintedUserdetails.mintedNFTs += 1;
                    MintedUserdetails.tokenIDs.push(totalUsersMintedTokenId);
                        
                    ERC721.safeMint(_Order.toAddr,totalUsersMintedTokenId,_Order.uri);
                }else{
                    revert("ETH transfer failed");
                }
        }else if(_Order.assetType == AssetType.USDT){
            require(USDTokenAmount > 0,"USDT amount invalid!!!");
            require(validateOrderHash(_Order,sig),"Incorrect signature while depositying USDT!!!");
            USDT.transferFrom(msg.sender,Mint_Owner,USDTokenAmount);
                totalUsersMintedTokenId += incrermentUsingAssemblyLanguageOpcodes.increment(totalUsersMintedTokenId);
                mintedUserDetails storage MintedUserdetails = MintedNFTsUserDetails[_Order.toAddr];
                MintedUserdetails.userAddr = _Order.toAddr;
                MintedUserdetails.mintedNFTs += 1;
                MintedUserdetails.tokenIDs.push(totalUsersMintedTokenId);
                        
                ERC721.safeMint(_Order.toAddr,totalUsersMintedTokenId,_Order.uri);
        }else{
           revert("Invalid assetType!!!");
        }
    }

    function validateOrderHash(Order memory _Order, Sig memory sig)internal pure returns(bool result){
        bytes32 Hash = prepareOrderHash(_Order);
        bytes32 fullMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", Hash)
        );
        address signatoryAddress = ecrecover(fullMessage,sig.v,sig.r,sig.s);
        result = signatoryAddress == _Order.toAddr;
    }

    function prepareOrderHash(Order memory _Order)public pure returns(bytes32){
        return keccak256(
            abi.encodePacked(
                _Order.toAddr,
                _Order.uri,
                _Order.assetType
            )
        );
    }

    function addToBlackList(address userAddress) public OnlyOwner{
        require(userAddress != address(0),"Zero address can't be blacklited!!!");
        require(!whiteListedUsers[userAddress],"Already BlackListed this user!!!");
        require(userAddress != Mint_Owner,"Owner can't be blacklisted!!!");
        whiteListedUsers[userAddress] = true;
    }   

    function addToWhiteList(address userAddress) public OnlyOwner{
        require(userAddress != address(0),"Zero address can't be whitelited!!!");
        require(whiteListedUsers[userAddress],"Only BlackListed users can be whiteListed!!!");
        whiteListedUsers[userAddress] = false;
    }
}